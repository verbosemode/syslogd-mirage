(**
   Taken from https://github.com/Engil/Canopy/blob/de93e06e0a60608e5c1e9b2582db75612346cf82/inflator.ml
   Special thanks to: @engil
*)
module IDBytes = struct
    include Bytes
    let concat = Bytes.concat
    let of_bytes s = s
    let to_bytes s = s
  end
module XInflator = Decompress.Inflate.Make(IDBytes)
module XDeflator = Decompress.Deflate.Make(IDBytes)

let inflate ?output_size buf =
  let output = match output_size with
    | None -> Bytes.create (Mstruct.length buf)
    | Some n -> Bytes.create n
  in
  let inflator = XInflator.make (`String (0, (Mstruct.to_string buf))) output in
  let rec eventually_inflate inflator acc =
    match XInflator.eval inflator with
    | `Ok n ->
       let res = Bytes.unsafe_to_string (IDBytes.concat (Bytes.unsafe_of_string "") (List.rev acc)) in
       Mstruct.shift buf n;
       Some (Mstruct.of_string res)
    | `Error -> None
    | `Flush _ ->
       match XInflator.contents inflator with
       | 0 ->
          let res = Bytes.unsafe_to_string (IDBytes.concat (Bytes.unsafe_of_string "") (List.rev acc)) in
          Some (Mstruct.of_string res)
       | _ ->
          let tmp = Bytes.copy output in
          XInflator.flush inflator;
          eventually_inflate inflator (tmp :: acc)
  in
  eventually_inflate inflator []

let deflate ?level buf =
  ignore(level);
  let output = Bytes.create 62 in
  let deflator = XDeflator.make ~window_bits:15
                                (`String (0, (Cstruct.to_string buf))) output in
  let rec eventually_deflate deflator acc =
    match XDeflator.eval deflator with
    | `Ok ->
       let res = IDBytes.concat (Bytes.unsafe_of_string "") (List.rev acc) |> Bytes.unsafe_to_string in
       Cstruct.of_string res
    | `Error -> failwith "Error deflating an archive :("
    | `Flush ->
       let n = Cstruct.len buf in
       let tmp = Bytes.create n in
       Bytes.blit output 0 tmp 0 n;
       XDeflator.flush deflator;
       eventually_deflate deflator (tmp :: acc)
  in
  eventually_deflate deflator []

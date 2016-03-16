(***
   TAKEN FROM: https://github.com/Engil/Canopy/blob/master/inflator.ml
   Special thanks to: @yomimono, @samoht, and Canopy team.
***)

module IDBytes = struct
    include Bytes
    let concat = String.concat
    let of_bytes t = t
    let to_bytes t = t
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
       let res = Mstruct.of_string (IDBytes.concat "" (List.rev acc)) in
       Mstruct.shift buf n;
       Some res
    | `Error -> None
    | `Flush n ->
       match XInflator.contents inflator with
       | 0 ->
          let res = Mstruct.of_string (IDBytes.concat "" (List.rev acc)) in
          Some res
       | _ ->
          let tmp = Bytes.copy output in
          XInflator.flush inflator;
          eventually_inflate inflator (tmp :: acc)
  in
  eventually_inflate inflator []

let deflate ?level buf =
  let output = Bytes.create 62 in
  let deflator = XDeflator.make ~window_bits:15
                                (`String (0, (Cstruct.to_string buf))) output in
  let rec eventually_deflate deflator acc =
    match XDeflator.eval deflator with
    | `Ok ->
       let res = IDBytes.concat "" (List.rev acc) in
       Cstruct.of_string res
    | `Error -> failwith "Error deflating an archive :("
    | `Flush ->
       let n = Cstruct.len buf in
       let tmp = Bytes.create n in
       Bytes.blit_string output 0 tmp 0 n;
       XDeflator.flush deflator;
       eventually_deflate deflator (tmp :: acc)
  in
  eventually_deflate deflator []

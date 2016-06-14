(* Taken from: https://raw.githubusercontent.com/Engil/Canopy/master/inflator.ml *)

module Inflate = Decompress.Inflate.Make(Decompress.ExtString)(Decompress.ExtBytes)
module Deflate = Decompress.Deflate.Make(Decompress.ExtString)(Decompress.ExtBytes)

let deflate ?level buff =
  let len      = Cstruct.len buff in
  let position = ref 0 in

  let input  = Bytes.create 1024 in
  let output = Bytes.create 1024 in
  let buffer = Buffer.create (Cstruct.len buff) in

  let refill' _ =
    let n = min (len - !position) 1024 in
    Cstruct.blit_to_bytes buff !position input 0 n;
    position := !position + n;
    if !position >= len then true, n else false, n
  in

  let flush' _ len =
    Buffer.add_subbytes buffer output 0 len;
    len
  in

  Deflate.compress ?level (Bytes.unsafe_to_string input) output refill' flush';
  Cstruct.of_string (Buffer.contents buffer)

let inflate ?output_size orig =
  let buff = Mstruct.clone orig in
  let output_size =
    match output_size with
    | None -> Mstruct.length orig
    | Some s -> s
  in
  let input  = Bytes.create 1024 in
  let output = Bytes.create 1024 in
  let buffer = Buffer.create output_size in
  let s      = ref 0 in

  let inflater = Inflate.make (Bytes.unsafe_to_string input) output in

  let refill' () =
    let n = min (Mstruct.length buff) 1024 in
    let i = Mstruct.get_string buff n in
    Bytes.blit_string i 0 input 0 n;
    n
  in

  let flush' len =
    Buffer.add_subbytes buffer output 0 len;
    len
  in

  let len = refill' () in
  Inflate.refill inflater len;
  Inflate.flush inflater 1024;

  let rec aux () = match Inflate.eval inflater with
    | `Ok ->
       let drop = flush' (Inflate.contents inflater) in
       s := !s + Inflate.used_in inflater;
       Inflate.flush inflater drop
    | `Flush ->
       let drop = flush' (Inflate.contents inflater) in
       Inflate.flush inflater drop;
       aux ()
    | `Wait ->
       let len = refill' () in
       s := !s + Inflate.used_in inflater;
       Inflate.refill inflater len;
       aux ()
    | `Error -> failwith "Inflate.inflate"
  in

  try aux ();
      Mstruct.shift orig !s;
      Some (Mstruct.of_string (Buffer.contents buffer))
  with _ -> None

open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (S:STACKV4) = struct

  module U  = S.UDPV4

  let start console s =
    let local_port = 5514 in
    S.listen_udpv4 s local_port (
      fun ~src ~dst ~src_port buf ->
        C.log_s console
          (red "UDP %s: \"%s\""
             (Ipaddr.V4.to_string src)
             (Cstruct.to_string buf))
          );

  S.listen s
end

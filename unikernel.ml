open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (S:STACKV4) = struct
  let start console s =
    let local_port = 5514 in
    S.listen_udpv4 s local_port (
      fun ~src ~dst ~src_port buf ->
        (* TODO MirageOS quiivalent of Unix.time () to build timestamp?? *)
        let ctx = {Syslog_message.hostname=(Ipaddr.V4.to_string src);
          timestamp={Syslog_message.month=1; day=1; hour=0; minute=0; second=0};
                   set_hostname=false} in
          match Syslog_message.parse ~ctx (Cstruct.to_string buf) with
            None -> C.log_s console (red "Failed: %s" (Cstruct.to_string buf))
          | Some msg ->
            C.log_s console (green "%s" (Syslog_message.pp_string msg))
    );

  S.listen s
end

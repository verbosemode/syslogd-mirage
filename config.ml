open Mirage

let stack = generic_stackv4 default_console tap0

let port =
  let doc = Key.Arg.info ~doc:"Listening port" ["p" ; "port" ] in
    Key.(create "port" Arg.(opt ~stage:`Both int 514 doc))

let main =
  foreign
    ~keys:[Key.abstract port]
    "Unikernel.Main" (console @-> stackv4 @-> clock @-> job)

let () =
  add_to_opam_packages["syslog-message"];
  add_to_ocamlfind_libraries["syslog-message"];
  register "syslogd" [main $ default_console $ stack $ default_clock]

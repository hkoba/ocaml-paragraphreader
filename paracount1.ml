(* -*- coding: utf-8 -*- *)

open Core.Std

module M = ParagraphReaderLBL

let () =
  if Array.length Sys.argv < 2 then
    Printf.printf "Usage: %s FILE\n" Sys.argv.(0)
  else
    let ic = In_channel.create Sys.argv.(1) in
    let npars = ref 0 in
    while Option.is_some (M.read ic) do
      incr npars
    done;
    Printf.printf "%d\n" !npars

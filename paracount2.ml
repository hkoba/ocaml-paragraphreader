(* -*- coding: utf-8 -*- *)

open Core.Std

module M = ParagraphReader

let () =
  if Array.length Sys.argv < 2 then
    Printf.printf "Usage: %s FILE\n" Sys.argv.(0)
  else
    let ic = In_channel.create Sys.argv.(1) in
    let reader = M.create ~debug:0 ~readsize:4096 ic in
    let npars = ref 0 in
    Gc.full_major ();
    while Option.is_some (M.read reader) do
      incr npars
    done;
    Printf.printf "%d\n" !npars

(* -*- coding: utf-8 -*- *)

open Core.Std

module ParaReader = struct
  let rec iter_until ~f ic =
    match In_channel.input_line ic with
    | None -> None
    | Some line ->
      match f line with
      | None -> iter_until ~f ic
      | Some v -> Some v

  let nonempty_line line =
    if line = "" then None else Some line

  let read ic =
    match iter_until ~f:nonempty_line ic with
    | None -> None
    | Some line ->
      let rec loop ic res =
	match In_channel.input_line ic with
	| None -> Some (String.concat ~sep:"\n" (List.rev res))
	| Some line ->
	  if line = "" then
	    Some (String.concat ~sep:"\n" (List.rev res))
	  else
	    loop ic (line :: res)
      in
      loop ic [line]      
end

module M = ParaReader

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

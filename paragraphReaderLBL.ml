(* -*- coding: utf-8 -*- *)

(* Read paragraph, Line by Line *)

open Core.Std

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

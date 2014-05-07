(* -*- coding: utf-8 -*- *)

open Core.Std
(** Perl5's defined-or operator *)
let (//) opt def = match opt with Some x -> x | None -> def

(*
  Paragraph here is text section delimited by \n\n.

  - [^\n]
  - \n (?! [^\n])
  - \n \n

  Txt: [^\n] region known not have \n\n
  Nl : \n    position \n found
  Unk:       unknown region. next search target
  Gbg:       garbage after finish.

  Each reading loop tries to find '\n' from Unk region.
  if '\n' found, it represents next Nl' region

  - Unk starts from pos+1
  - Gbg starts from finish

*)

type t = {
  ic: in_channel;
  readbuf: string;
  mutable nlpos: int;
  mutable finish: int;
  outbuf: Buffer.t;
  mutable eof: bool;
  mutable debug: bool
}

let unknown_len t =
  t.finish - t.nlpos - 1

let create ?(readsize=256) ?(debug=false) ic =
  {ic; debug;
   readbuf = String.create readsize;
   outbuf = Buffer.create readsize;
   nlpos = -1; finish = 0; eof = false}

let readbuf_contents t =
  assert (t.nlpos < 0 || t.readbuf.[t.nlpos] = '\n');
  let start = max t.nlpos 0 in
  String.sub ~pos:start ~len:(t.finish - start) t.readbuf

let outbuf_contents t =
  Buffer.contents t.outbuf

let shift_readbuf t =
  if t.debug then
    print_endline "shifting..";
  let len = t.finish - (max t.nlpos 0) in
  if len > 0 then
    String.blit ~src:t.readbuf ~src_pos:t.nlpos ~dst:t.readbuf ~dst_pos:0 ~len;
  t.nlpos <- if len > 0 && t.readbuf.[0] = '\n' then 0 else -1;
  t.finish <- len

let pump_readbuf t =
  let len = String.length t.readbuf - t.finish in
  let got = In_channel.input t.ic ~buf:t.readbuf ~pos:t.finish ~len in
  t.finish <- got + t.finish;
  if got = 0 then
    t.eof <- true

let flush_readbuf ?(fin) t =
  if t.debug then
    (Printf.printf "  flushing nlpos=%d fin=%d\n" t.nlpos t.finish;
     flush stdout);
  let finish = fin // t.finish in
  let start = max t.nlpos 0 in
  Buffer.add_substring t.outbuf t.readbuf start (finish - start);
  t.nlpos <- fin // -1;
  if t.debug then
    (Printf.printf "  flushed nlpos=%d\n" t.nlpos; flush stdout)

let emit_outbuf t =
  let out = Buffer.contents t.outbuf in
  Buffer.reset t.outbuf;
  while t.nlpos < t.finish && t.readbuf.[t.nlpos] = '\n' do
    t.nlpos <- t.nlpos + 1
  done;
  out

let str_index_from ~pos ?fin ch str =
  let fin = fin // String.length str in
  let rec loop pos fin ch str =
    if pos > fin then
      None
    else if str.[pos] = ch then
      Some pos
    else
      loop (pos+1) fin ch str
  in
  loop pos fin ch str

let read t =
  let rec loop t =
    if t.debug then
      (Printf.printf "#readbuf=[%s] outbuf=[%s]\n"
	 (readbuf_contents t) (outbuf_contents t);
       flush stdout);
    if unknown_len t > 0 then (
      match str_index_from ~pos:(t.nlpos+1) ~fin:t.finish '\n' t.readbuf with
      | None -> (
	if t.debug then
	  print_endline "no newline";
	flush_readbuf t; loop t
      )
      | Some i -> (
	if t.debug then
	  print_endline "has newline";
	if i = t.nlpos+1 then (
	  Some(emit_outbuf t)
	) else (
	  flush_readbuf ~fin:i t; (* \n remains in readbuf *)
	  if i+1 < t.finish && t.readbuf.[i+1] = '\n' then (
	    Some(emit_outbuf t)
	  ) else (
	    shift_readbuf t;
	    pump_readbuf t;
	    loop t
	  )
	)
      )
    ) else if not t.eof then
	(pump_readbuf t; loop t)
      else
	None
  in
  loop t

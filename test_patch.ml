open Patch
open Assertions

let rec repeat n f =
  if n = 0 then () else
  let _ = f n in repeat (n - 1) f

let random_text n =
  let random_char () = Char.escaped (Char.chr (65 + (Random.int 26))) in
  let rec go s n = 
    if n = 0 then s
    else go (s ^ (random_char ())) (n - 1)
  in
  go "" n

let rand0 n = if n = 0 then 0 else (Random.int n) mod n

let random_edit doc =
  let doc_size = String.length doc in
  let op = if (rand0 2 = 0) || (doc_size = 0) then Insert else Delete in
  let pos = rand0 (doc_size + 1) in
  let text =
    if op = Insert
    then random_text (rand0 10)
    else String.sub doc pos (rand0 (doc_size - pos)) in
  {op = op; pos = pos; text = text}

let offset edit =
  let sign edit =
    (match edit.op with
    | Insert -> 1
    | Delete -> -1)
  in
  (sign edit) * (String.length edit.text)

let rec random_edits n doc =
  if n = 0 then ([], doc) else
  let edit = random_edit doc in
  let (p, doc') = random_edits (n - 1) (apply_patch doc [edit]) in
  (compose [edit] p, doc')

let random_patch max_size doc =
  let num_edits = Random.int max_size in
  random_edits num_edits doc

(*
TEST_UNIT =
  repeat 100 (fun _ ->
    let doc_size = 10 in
    let doc_text = random_text doc_size in
    let (p, s) = random_patch 50 doc_text in
    let _ =  Printf.printf "%s\n%s\n%s\n\n" doc_text (string_of_patch p) s in
    (apply_patch doc_text p) === s
  )
*)

(* Empty patch does not change the document's text *)
TEST_UNIT =
  repeat 1000 (fun _ ->
  let doc_size = Random.int 2000 in
  let doc_text = random_text doc_size in
  let edit_list = [] in
  apply_patch doc_text edit_list === doc_text
  )

(* Applying patch composed with its inverse to empty document results in the
 * empty document. *)

TEST_UNIT =
  repeat 1000 (fun _ ->
  let doc_text = empty_doc in (* will just be "" *)
  let edit_list = fst (random_patch 50 doc_text) in
  apply_patch doc_text (compose edit_list (inverse edit_list)) ===
    apply_patch doc_text empty_patch
  )


(* Applying patch composed with its inverse to non-empty document results in
 * the original document text *)
TEST_UNIT =
  repeat 1000 (fun _ ->
  let doc_size = Random.int 2000 in
  let doc_text = random_text doc_size in
  let edit_list = fst (random_patch 50 doc_text) in
  let doc1 = apply_patch doc_text edit_list in
  let doc2 = apply_patch doc1 (inverse edit_list) in
  let doc3 = apply_patch doc2 edit_list in
  doc1 === doc3
  )


(* Applying patch composed with another patch to an empty document is the same as
 * applying the second patch to the empty document and then applying the first
 * patch. *)
TEST_UNIT =
  repeat 1000 (fun _ ->
  let (edit_list, s1) = random_patch 50 empty_doc in
  let edit_list2 = fst (random_patch 50 s1) in
  apply_patch empty_doc (compose edit_list edit_list2) ===
    apply_patch (apply_patch empty_doc edit_list) edit_list2
  )

TEST_UNIT =
  repeat 1000 (fun i ->
    let doc_size = Random.int 2000 in
    let doc_text = random_text doc_size in
    let (p1, s1) = random_patch 50 doc_text in
    let (p2, s2) = random_patch 50 doc_text in
    let (p2', p1') = merge p1 p2 in
    let doc1 = apply_patch doc_text (compose p1 p2') in
    let doc2 = apply_patch doc_text (compose p2 p1') in
    doc1 === doc2
  )

(* string_of_patch and patch_of_string are inverses *)
TEST_UNIT =
  repeat 1000 (fun _ ->
    let edit_list = fst (random_patch 50 empty_doc) in
    let s = string_of_patch edit_list in
    patch_of_string s === edit_list;
    string_of_patch (patch_of_string s) === s
  )

let _ = Pa_ounit_lib.Runtime.summarize ()

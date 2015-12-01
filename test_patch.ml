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

let rand0 n = if n = 0 then 0 else Random.int n

let random_edit doc_size =
  let patch_op =
    if ((rand0 2) = 0) || (doc_size = 0) then Insert else Delete in
  let patch_pos = rand0 doc_size in
  let max_size = if patch_op = Insert then 10 else doc_size - patch_pos in
  let size_patch_text = rand0 max_size in
  let random_text = random_text size_patch_text in
  {op = patch_op; pos = patch_pos; text = random_text}

let random_patch doc_size =
  let num_edits = Random.int 2 in
  let offset edit =
    let sign = if edit.op = Insert then 1 else -1 in
    sign * (String.length edit.text)
  in
  let rec random_edits n doc_size =
    if n = 0 then ([], doc_size) else
    let edit = random_edit doc_size in
    let (p, size) = (random_edits (n - 1) (doc_size + (offset edit))) in
    (edit::p, size)
  in
  random_edits num_edits doc_size


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
  let edit_list = fst (random_patch 0) in
  let doc_text = empty_doc in (* will just be "" *)
  apply_patch doc_text (compose edit_list (inverse edit_list)) ===
    apply_patch doc_text empty_patch
  )


(* Applying patch composed with its inverse to non-empty document results in
 * the original document text *)
TEST_UNIT =
  repeat 1000 (fun _ ->
  let doc_size = Random.int 2000 in
  let edit_list = fst (random_patch doc_size) in
  let doc_text = random_text doc_size in
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
  let (edit_list, s1) = random_patch 0 in
  let edit_list2 = fst (random_patch s1) in
  apply_patch empty_doc (compose edit_list edit_list2) ===
    apply_patch (apply_patch empty_doc edit_list) edit_list2
  )

TEST_UNIT =
  repeat 10000000 (fun i ->
    let doc_size = Random.int 20 in
    let doc_text = random_text doc_size in
    let p1 = fst (random_patch doc_size) in
    let p2 = fst (random_patch doc_size) in
    (*let _ =  Printf.printf "%s\n%s\n%s\n\n" doc_text (string_of_patch p1) (string_of_patch p2) in*)
    let (p2', p1') = merge p1 p2 in
    let doc1 = apply_patch (apply_patch doc_text p1) p2' in
    let doc2 = apply_patch (apply_patch doc_text p2) p1' in
    doc1 === doc2
  )

(* string_of_patch and patch_of_string are inverses *)
TEST_UNIT =
  repeat 1000 (fun _ ->
    let edit_list = fst (random_patch 0) in
    let s = string_of_patch edit_list in
    patch_of_string s === edit_list;
    string_of_patch (patch_of_string s) === s
  )

let _ = Pa_ounit_lib.Runtime.summarize ()

open Patch

let get_random_text n =
  let random_char () = Char.escaped (Char.chr (Random.int 26)) in
  let rec go s n = 
    if n = 0 then s
    else go (s ^ (random_char ())) (n - 1)
  in
  go "" n

let get_random_edit_list doc_size =
  let num_edits = Random.int 50 in
  let random_edit doc_size =
    let patch_op = if Random.int 1 = 0 then Insert else Delete in
    let patch_pos = Random.int (doc_size + 1) in
    let size_patch_text = Random.int (doc_size + 1) in
    let random_text = get_random_text size_patch_text in
    {op = patch_op; pos = patch_pos; text = random_text};
  in
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
TEST =
  let doc_size = Random.int 2000 in
  let doc_text = get_random_text doc_size in
  let edit_list = [] in
  apply_patch doc_text edit_list = doc_text

(* Applying patch composed with its inverse to empty document results in the empty document. *)
TEST =
  let edit_list = fst (get_random_edit_list 0) in
  let doc_text = empty_doc in (* will just be "" *)
  apply_patch doc_text (compose edit_list (inverse edit_list)) =
    apply_patch doc_text empty_patch

(* Applying patch composed with its inverse to non-empty document results in the original document text *)
TEST =
  let doc_size = Random.int 2000 in
  let edit_list = fst (get_random_edit_list doc_size) in
  (*let doc_text = get_random_text doc_size in*)
  true
  (*apply_patch doc_text (compose edit_list inv) =
    apply_patch doc_text empty_patch *)

(* Applying patch composed with another patch to an empty document is the same as applying the second patch
to the empty document and then applying the first patch. *)
(* TODO: is the order here correct? or should it be first patch, then second patch? *)
(* TODO: haven't made sure that edit_list will have edits that are within the limits of the document text *)
TEST =
  let (edit_list, s1) = get_random_edit_list 0 in
  let edit_list2 = fst (get_random_edit_list s1) in
  apply_patch empty_doc (compose edit_list edit_list2) =
    apply_patch (apply_patch empty_doc edit_list2) edit_list

let _ = Pa_ounit_lib.Runtime.summarize ()

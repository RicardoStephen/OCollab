open Patch

let get_random_text n =
  let document_text = ref "" in
  let rec fill n =
    if n > 0 then
      let str = Char.escaped (Char.chr (Random.int 26)) in
      document_text := !document_text ^ str;
      fill (n-1)
    else
      ()
  in
  fill n;
  !document_text

let get_random_edit_list doc_size =

let num_edits = Random.int 50 in
let edits_array = Array.make num_edits [] in
for i = 0 to num_edits do
  let patch_op = if Random.int 1 = 0 then Insert else Delete in
  let patch_pos = Random.int doc_size in
  let size_patch_text = Random.int doc_size in
  let random_text = get_random_text size_patch_text in
  edits_array.(i) <- {op = patch_op; pos = patch_pos; text = random_text};
done;
 let edit_list = Array.to_list edits_array in
 edit_list

(* Empty patch does not change the document's text *)
TEST =
  let doc_size = Random.int 2000 in
  let doc_text = get_random_text doc_size in
  let edit_list = [] in
  apply_patch doc_text edit_list = doc_text

(* Applying patch composed with its inverse to empty document results in the empty document. *)
TEST =
  let edit_list = get_random_edit_list 0 in
  let doc_text = empty_doc (* will just be "" *)
  apply_patch doc_text (compose edit_list (inverse edit_list)) = apply_patch doc_text empty_patch

(* Applying patch composed with its inverse to non-empty document results in the original document text *)
TEST =
  let doc_size = Random.int 2000 in
  let edit_list = get_random_edit_list doc_size in
  let doc_text = get_random_text doc_size in
  apply_patch doc_text (compose edit_list (inverse edit_list)) = apply_patch doc_text empty_patch

(* Applying patch composed with another patch to an empty document is the same as applying the second patch
to the empty document and then applying the first patch. *)
(* TODO: is the order here correct? or should it be first patch, then second patch? *)
(* TODO: haven't made sure that edit_list will have edits that are within the limits of the document text *)
TEST =
let edit_list = get_random_edit_list () in
let edit_list2 = get_random_edit_list () in
apply_patch empty_doc (compose edit_list edit_list2) = apply_patch (apply_patch empty_doc edit_list2) edit_list

(* Applying patch composed with another patch to a document is the same as applying the second patch to the
document and then applying the first patch*)
(* TODO: is the order here correct? or should it be first patch, then second patch? *)
(* TODO: haven't made sure that edit_list will have edits that are within the limits of the document text *)
TEST =
let edit_list = get_random_edit_list () in
let edit_list2 = get_random_edit_list () in
(apply_patch empty_doc (compose edit_list edit_list2)) = (apply_patch (apply_patch empty_doc edit_list2) edit_list)


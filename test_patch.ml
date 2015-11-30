open Patch
open Assertions

(*
Properties to check for:
-performing patch and then its inverse is the empty patch
-check whether composing two patches works. -- it should be that it's equal to applying first patch, then the other
  (or is it second patch, then first.)
 *)
(*
(* Random testing *)
let get_random_text n =
  let document_text = ref "" in
  let fill n =
    let str = Char.escaped (Char.chr (Random.int 25)) in
    document_text := !document_text ^ str;
  in
  fill n;
  !document_text


let doc_size = Random.int 2000 in
let doc_text = get_random_text doc_size in

let num_edits = Random.int 50 in
for 0 to num_edits do
  let patch_op = if Random.int 1 = 0 then Insert else Delete in
  let patch_pos = Random.int doc_size in
  let size_patch_text = Random.int doc_size in
  let random_text = get_random_text size_patch_text in
  let edit_lst = lst @ [{op = patch_op; pos = patch_pos; text = random_text}] in
done
*)
(* Random testing *)
let get_random_text n =
  let document_text = ref "" in
  let fill n =
    let str = Char.escaped (Char.chr (Random.int 25)) in
    document_text := !document_text ^ str;
  in
  fill n;
  !document_text

let get_random_edit_list () =
let doc_size = Random.int 2000 in
let doc_text = get_random_text doc_size in

let num_edits = Random.int 50 in
let edits_array = Array.make num_edits [] in
for i = 0 to num_edits do
  let patch_op = if Random.int 1 = 0 then Insert else Delete in
  let patch_pos = Random.int doc_size in
  let size_patch_text = Random.int doc_size in
  let random_text = get_random_text size_patch_text in
  edits_array.(i) <- {op = patch_op; pos = patch_pos; text = random_text};
done
let edit_list = Array.to_list edits_array in
edit_list

TEST_UNIT =
(*let doc_size = Random.int 2000 in
let doc_text = get_random_text doc_size in

let num_edits = Random.int 50 in
let edits_array = Array.make num_edits [] in
for i = 0 to num_edits do
  let patch_op = if Random.int 1 = 0 then Insert else Delete in
  let patch_pos = Random.int doc_size in
  let size_patch_text = Random.int doc_size in
  let random_text = get_random_text size_patch_text in
  edits_array.(i) <- {op = patch_op; pos = patch_pos; text = random_text};
done
let edit_list = Array.to_list edits_array in
*)
let edit_list = get_random_edit_list () in
compose edit_list (inverse edit_list) === empty_patch


TEST_UNIT =
let edit_list = get_random_edit_list () in
let edit_list2 = get_random_edit_list () in
apply_patch empty_doc (compose edit_list edit_list2) === apply_patch (apply_patch empty_doc edit_list2) edit_list

TEST_UNIT =
let edit_list = get_random_edit_list () in
let edit_list2 = get_random_edit_list () in
apply_patch empty_doc (compose edit_list edit_list2) === apply_patch (apply_patch empty_doc edit_list2) edit_list

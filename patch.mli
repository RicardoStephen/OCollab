(*
 * Patch Module
 *
 *)

type operation

type patch

type document_text

(*
 * A patch which represents doing nothing to a document.
 *)
val empty_patch : patch

(*
 * Empty document text
 *)
val empty_doc: document_text

(*
 * Adds an operation to a patch.
 *)
val add_op : operation -> patch -> patch

(*
 * Compute the inverse of a patch, which represents undoing a patch.
 *)
val inverse : patch -> patch

(*
 * Composes two patches in order to form a new patch representing doing patch1
 * and then patch2.
 *)
val compose : patch -> patch -> patch

(*
 * Identities for empty, inverse, and compose:
 * compose empty p1           = p1
 * compose p1 empty           = p1
 * compose (compose p1 p2) p3 = compose p1 (compose p2 p3)
 * compose p1 (inverse p1)    = empty
 * compose (inverse p1) p1    = empty
 *)

(*
 * Given two patches, computes two other patches which can be composed to bring
 * the two patches to a common state.
 *
 * Suppose that merge p1 p2 = (q1, q2). Then compose p1 q1 = compose p2 q2. As
 * much as possible, if there are some other q1' and q2' such that
 * compose p1 q1' = compose p2 q2', then there is a patch q3 such that
 * compose p1 (compose q1 q3) = compose p1 q1' and
 * compose p2 (compose q2 q3) = compose p2 q2'.
 *)
val merge : patch -> patch -> (patch, patch)

(*
 * Applies a patch to modify a document represented as a string.
 *)
val apply_patch : document_test -> patch -> document_test

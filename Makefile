
# Bytecode compiler
OCC=ocamlfind ocamlc
# Native compiler
OCN=ocamlfind ocamlopt

# Client side packages
CLIENT_PKGS=
# Server side packages
SERVER_PKGS=yojson,redis,netstring,eliom.server
# Unit test packages
TEST_PKGS=pa_ounit,yojson,redis

TEST_LIBS=storage.cmx document.cmx serializer.cmx assertions.cmx

.PHONY: all eliom_test server

.PRECIOUS: %.cmi %.cmo %.cmx %.o

all: run

compile: patch.cmo document.cmo storage.cmo editor.cmo

server:
	$(MAKE) create_doc.js
	$(MAKE) gui.js
	$(MAKE) clean
	$(MAKE) run

create_doc.js:
	ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml.syntax -syntax camlp4o -linkpkg -o static/create_doc.o static/create_doc.ml
	js_of_ocaml static/create_doc.o

gui.js: static/gui.ml patch.cmo
	ocamlfind ocamlc -package js_of_ocaml,yojson -package js_of_ocaml.syntax -syntax camlp4o -linkpkg -o static/gui.o patch.cmo static/gui.ml
	js_of_ocaml -opt 3 static/gui.o

gui_test.js: gui_test.ml
	ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml.syntax -syntax camlp4o -linkpkg -o gui_test.o gui_test.ml
	js_of_ocaml -opt 3 gui_test.o

eliom_test: 
	ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml.syntax -syntax camlp4o -linkpkg -o eliom_test/static/gui_js.byte eliom_test/gui_js.ml
	js_of_ocaml eliom_test/static/gui_js.byte
	cd eliom_test && $(MAKE) test.byte

test_%: test_%.ml patch.cmx $(TEST_LIBS)
	$(OCN) -o $@ -linkall -thread -linkpkg -package $(TEST_PKGS) -syntax camlp4o patch.cmx -package pa_ounit.syntax $(TEST_LIBS) $< 

%.cmo: %.ml %.cmi
	$(OCC) -o $@ -linkpkg -package $(SERVER_PKGS) -thread -c $<

%.cmx: %.ml %.cmi
	$(OCN) -o $@ -linkpkg -package $(SERVER_PKGS) -thread -c $<

%.cmi: %.mli
	$(OCC) -o $@ -linkpkg -package $(SERVER_PKGS) -thread -c $<

test: compile test_patch test_storage
	./test_patch inline-test-runner dummy -log -verbose
	./test_storage inline-test-runner dummy -log -verbose

run: compile
	@-mkdir -p server/log
	@-mkdir -p server/data
	ocsigenserver -c editor.conf

clean:
	@-rm -r _build
	@-rm -r _cs3110
	@-rm *.cmi
	@-rm *.cmo
	@-rm *.cmx
	@-rm *.o
	@-rm test_patch
	@-rm test_storage

install:
	opam install -y yojson
	opam install -y js_of_ocaml
	opam depext dbm.1.0
	opam install -y eliom
	sudo apt-get install -y redis-server
	opam install -y redis


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

.PHONY: all compile test run install

.PRECIOUS: %.cmi %.cmo %.cmx %.o

all: compile
	@-mkdir -p server/log
	@-mkdir -p server/data
	ocsigenserver -c server.conf

compile: patch.cmo document.cmo storage.cmo server.cmo gui.js

gui.js: static/gui.ml patch.cmo
	ocamlfind ocamlc -package js_of_ocaml,yojson -package js_of_ocaml.syntax -syntax camlp4o -linkpkg -o static/gui.o patch.cmo static/gui.ml
	js_of_ocaml --opt 3 static/gui.o

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

clean:
	@-rm -r _build
	@-rm -r _cs3110
	@-rm *.cmi
	@-rm *.cmo
	@-rm *.cmx
	@-rm *.o
	@-rm ./static/*.cmi
	@-rm ./static/*.cmo
	@-rm ./static/*.cmx
	@-rm ./static/*.o
	@-rm ./static/*.js
	@-rm test_patch
	@-rm test_storage

install:
	opam install -y yojson
	opam install -y js_of_ocaml
	opam install -y depext
	opam depext dbm.1.0
	opam install -y eliom
	sudo apt-get install -y redis-server
	opam install -y redis


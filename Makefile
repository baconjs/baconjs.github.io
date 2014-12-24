.PHONY : all dev

COFFEE ?= coffee

all : 
	$(COFFEE) generator/generate.coffee

dev : 
	$(COFFEE) generator/generate.coffee dev

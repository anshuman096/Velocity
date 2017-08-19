.SUFFIXES: .vel .test

SRCS = ${wildcard test/*.vel}
TARGETS = $(subst vel,test, ${SRCS})
SOURCEJSON = src/velocity.jison

parser: ${SOURCEJSON}
	jison ${SOURCEJSON}
	mv velocity.js bin

test: ${TARGETS}
.vel.test:
	node bin/velocity.js $<

clean:
	rm bin/velocity.js
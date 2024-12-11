import std.stdio;

import bindbc.sdl;
import std.string;
import std.algorithm;

import pyd.pyd, pyd.embedded;

shared static this() {
    py_init();
}
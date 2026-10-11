"""Run the UXCBASIC tests: compile each tests/*.UXB with build/UXC.PRG, run it, and compare.

    python tests.py [NAME ...] [--update]

Each test is a source NAME.UXB and its expected output NAME.OUT, both in tests/. A source
that compiles is run, and what it printed is compared with NAME.OUT. When tests/NAME.IN
exists, its lines are typed on the keyboard during the run. When tests/NAME.NEXT exists,
it names the PRG that UXC.INPUT line 3 chains to, and that PRG's output is compared. A
source that does not compile is compared by its result line, so an error test's NAME.OUT
is one line:

    ERROR,<line>,<message>

NAMEs pick tests; with none, every test runs. --update writes NAME.OUT from what the test
gave, for a new test or a change made on purpose: read the .OUT it wrote before you keep
it. Build UXC first (build.py UXC). Exit status 1 when a test failed.
"""

import glob
import os
import shutil
import sys
import time

from uxc import DRIVE, RESULT, compile_source, emulate, run_prg

HERE = os.path.dirname(os.path.abspath(__file__))
TESTS = os.path.join(HERE, "tests")


def chained(source, prg):
    """Compile source with UXC.INPUT line 3 naming prg. Return what prg printed after UXC
    loaded it, or the compile result line when the compile failed."""
    shutil.copyfile(source, os.path.join(DRIVE, os.path.basename(source).upper()))
    with open(os.path.join(DRIVE, "UXC.INPUT"), "w", newline="\n") as out:
        out.write("%s\nUXC.RESULT\n%s\n" % (os.path.basename(source).upper(), prg))
    if os.path.exists(RESULT):
        os.remove(RESULT)
    # READY. comes at boot, after the load of UXC, after UXC ends, after the LOAD of prg, and
    # after prg ends. prg's output lies between the fourth and the fifth.
    text = emulate(os.path.join(DRIVE, "UXC.PRG"), 30, until=lambda t: t.count("READY.") >= 5)
    if not os.path.exists(RESULT):
        return "NO RESULT FROM UXC"
    result = open(RESULT, "rb").read().decode("latin-1").strip()
    if not result.startswith("OK,"):
        return result
    lines = text.replace("\\X0F", "").split("\n")
    ready = [i for i, l in enumerate(lines) if l == "READY."]
    if len(ready) < 5:
        return "%s DID NOT RUN" % prg
    return "\n".join(lines[ready[3] + 1:ready[4]]).strip("\n")


def outcome(source):
    """What a test gave: the program's output, or its compile result line. When
    tests/NAME.NEXT exists, UXC chains to the PRG it names, and that PRG's output counts."""
    chain = os.path.splitext(source)[0] + ".NEXT"
    if os.path.exists(chain):
        return chained(source, open(chain, encoding="latin-1").read().strip())
    result, screen = compile_source(source)
    if result is None:
        return "NO RESULT FROM UXC"
    fields = result.split(",")
    if fields[0] != "OK":
        return result
    keys = os.path.splitext(source)[0] + ".IN"
    typed = None
    if os.path.exists(keys):
        typed = open(keys, encoding="latin-1").read().replace("\r\n", "\n")
    out = run_prg(fields[1], typed=typed)
    return "%s DID NOT LOAD" % fields[1] if out is None else out


def expected(path):
    if not os.path.exists(path):
        return None
    text = open(path, encoding="latin-1").read()
    return text.replace("\r\n", "\n").replace("\r", "\n").rstrip("\n")


def main():
    args = sys.argv[1:]
    update = "--update" in args
    names = [a.upper() for a in args if not a.startswith("--")]
    if not os.path.exists(os.path.join(DRIVE, "UXC.PRG")):
        sys.exit("tests: no build/UXC.PRG; run build.py UXC first")
    sources = sorted(glob.glob(os.path.join(TESTS, "*.UXB")))
    if names:
        sources = [s for s in sources if os.path.splitext(os.path.basename(s))[0].upper() in names]
        if len(sources) != len(names):
            sys.exit("tests: no such test among %s" % " ".join(names))
    for include in glob.glob(os.path.join(TESTS, "*.UXI")) + glob.glob(os.path.join(HERE, "lib", "*.UXI")):
        shutil.copyfile(include, os.path.join(DRIVE, os.path.basename(include).upper()))
    failed = []
    started = time.time()
    for source in sources:
        name = os.path.splitext(os.path.basename(source))[0]
        out_path = os.path.splitext(source)[0] + ".OUT"
        took = time.time()
        got = outcome(source).rstrip("\n")
        took = time.time() - took
        want = expected(out_path)
        if update:
            with open(out_path, "w", encoding="latin-1", newline="\n") as out:
                out.write(got + "\n")
            print("WROTE %-12s %4.1f s" % (name, took))
            continue
        if got == want:
            print("ok    %-12s %4.1f s" % (name, took))
            continue
        failed.append(name)
        print("FAIL  %-12s %4.1f s" % (name, took))
        if want is None:
            print("      no %s.OUT; it gave:" % name)
            for line in got.split("\n"):
                print("      | " + line)
            continue
        print("      expected:")
        for line in want.split("\n"):
            print("      | " + line)
        print("      got:")
        for line in got.split("\n"):
            print("      | " + line)
    print("%d tests, %d failed, %d s" % (len(sources), len(failed), time.time() - started))
    if failed:
        print("failed: " + " ".join(failed))
        sys.exit(1)


main()

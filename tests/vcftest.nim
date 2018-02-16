import unittest, hts, strutils

suite "vcf suite":
  test "test writer":

    var tsamples = @["101976-101976", "100920-100920", "100231-100231", "100232-100232", "100919-100919"]
    var v:VCF
    var wtr:VCF
    check open(v, "tests/test.vcf.gz", samples=tsamples)
    check open(wtr, "tests/out.vcf", mode="w")
    wtr.header = v.header
    check wtr.write_header()
    var variant:Variant
    var i = 0

    for variant in v:
      var val = @[0.6789'f32]
      check variant.info.set("VQSLOD", val) == Status.OK
      # or for a single value:
      var val1 = 0.77
      check variant.info.set("VQSLOD", val1) == Status.OK

      check variant.info.delete("CSQ") == Status.OK

      var mq0 = @[10000'i32]
      check variant.info.set("MQ0", mq0) == Status.OK

      var found = variant.tostring().contains("culprint")
      check (not found)

      var culprit = "Test"
      check variant.info.set("culprit", culprit) == Status.OK
      check wtr.write_variant(variant)

      check ("culprit" in variant.tostring())

      if i == 0:
        try:
          discard variant.info.delete("XXX")
          check false
        except KeyError:
          check true
      i += 1


    wtr.close()


  test "test format setting":
    var tsamples = @["101976-101976", "100920-100920", "100231-100231", "100232-100232", "100919-100919"]
    var vcf:VCF
    check open(vcf, "tests/test.vcf.gz", samples=tsamples)

    var val = @[2'i32, 2, 2, 2, 2]
    var vout = new_seq[int32](5)
    for variant in vcf:
      check variant.format.set("MIN_DP", val) == Status.OK

      check variant.format.ints("MIN_DP", vout) == Status.OK

      check vout == val


      var val2 = @[2'i32, 2, 2, 2]
      check variant.format.set("MIN_DP", val2) == Status.IncorrectNumberOfValues

{ lib, buildPythonPackage, pythonOlder, fetchPypi, cryptography }:

buildPythonPackage rec {
  pname = "pyglome";
  version = "0.0.2";
  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1djwyhib31vqacq4ipfr260krmq44893mgmvrlfbd8m6mr5x2511";
  };

  propagatedBuildInputs = [ cryptography ];
  pythonImportsCheck = [ "pyglome" ];

  meta = with lib; {
    description = "A Python implementation of the GLOME protocol";
    license = licenses.asl20;
    homepage = "https://github.com/google/glome";
    maintainers = with maintainers; [ delroth ];
  };
}

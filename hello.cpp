#include <iostream>
#include <fstream>

int main()
{
  std::string m;
  std::ifstream stream("/sys/firmware/devicetree/base/model");
  std::getline(stream, m);

  std::cout << m << std::endl;

  return 0;
}

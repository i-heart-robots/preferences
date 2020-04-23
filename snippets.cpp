// ----- Problem 1 ------------------------------------------------------------
#include <iostream>

class Base1 {
 public:
  Base1() { std::cout << "Base1's constructor called" << std::endl; }
};

class Base2 {
 public:
  Base2() { std::cout << "Base2's constructor called" << std::endl; }
};

class Derived : public Base1, public Base2 {
 public:
  Derived() { std::cout << "Derived's constructor called" << std::endl; }
};

int main() {
  Derived d;
  return 0;
}

// Q. What is the output?
// A. Base1, Base2, Derived. In order of declared inheritance, then derived.

// ----- Problem 2 ------------------------------------------------------------
#include <iostream>

class Base1 {
 public:
  ~Base1() { std::cout << "Base1's destructor" << std::endl; }
};

class Base2 {
 public:
  ~Base2() { std::cout << "Base2's destructor" << std::endl; }
};

class Derived : public Base1, public Base2 {
 public:
  ~Derived() { std::cout << "Derived's destructor" << std::endl; }
};

int main() {
  Derived d;
  return 0;
}

// Q. What is the output?
// A. Derived, Base2, Base1.  First derived, then in reverse order of inheritance.

// ----- Problem 3a -----------------------------------------------------------
#include <iostream>

class base {
  int arr[10];
};

class b1 : public base {};

class b2 : public base {};

class derived : public b1, public b2 {};

int main(void) {
  std::cout << sizeof(derived) << std::endl;
  return 0;
}

// Q. What is the output?
// A. 80 if int=4bytes.
// b1 & b2 inherit from base, so derived has two copies of 'arr[10]'

// ----- Problem 3b -----------------------------------------------------------
// Adding virtualization can save space
#include <iostream>

class base {
  int arr[10];
};

class b1 : virtual public base {};

class b2 : virtual public base {};

class derived : public b1, public b2 {};

int main(void) {
  cout << sizeof(derived);
  return 0;
}

// Q. What is the output?
// A. 48 if int=4bytes.
// 40 bytes for 'int arr[10]' and 8 bytes for vtable

// ----- Problem 4 ------------------------------------------------------------
#include <iostream>

class P {
 public:
  void print() { cout << "Inside P"; }
};

class Q : public P {
 public:
  void print() { cout << "Inside Q"; }
};

class R : public Q {};

int main(void) {
  R r;
  r.print();
  return 0;
}

// Q. What is the output?
// A. "Inside Q".  Searches up the ineritance tree (R, Q, P) until a match is found.

// ----- Problem 5 ------------------------------------------------------------
// Q. Why does a pre-processor directive not have a semi-colon at the end?
// A. Semi-colons are needed by the compiler.  Preprocessors process source code *before*
//    compilation.

// ----- Problem 6 ------------------------------------------------------------
// Q. What is the difference between including the header file with < > and ” “?
// A. If < >, the compiler searches the built-in include path.
//    If ” “, the compiler searches first the current working directory, then the built-in include
//    path.

// ----- Problem 7 ------------------------------------------------------------
// Q. What are stack and heap areas?
// A. Heap: Stores objects allocated dynamically (e.g. new, malloc() or calloc()).
//    Stack: Stores local variables and arguments - stays in memory only until scope ends.

// ----- Problem 8 ------------------------------------------------------------
// Q. Structure vs class in C++
// A. In C++, a structure is the same as a class except the following differences:
//    - Members of a class are private by default and members of struct are public by default.
//    - When deriving a struct from a class/struct, default access-specifier for a base class/struct
//    is public. And when deriving a class, default access specifier is private.

// ----- Problem 9 ------------------------------------------------------------
// Q. Replace the 'shuffle' function w/ something more 'appropriate'
#include <algorithm>
#include <iostream>
#include <numeric>
#include <vector>

void shuffle(std::vector<int>& cards) { std::reverse(cards.begin(), cards.end()); }

int main() {
  std::vector<int> cards(52);
  std::iota(cards.begin(), cards.end(), 0);
  for (const auto& card : cards) {
    std::cout << card << ", ";
  }
  std::cout << std::endl;
  shuffle(cards);
  for (const auto& card : cards) {
    std::cout << card << ", ";
  }
  return 0;
}

// OR

// -->
// Example program
#include <iostream>
#include <random>
#include <string>

void shuffle(int cards[52]) {
  for (int ii = 0; ii < 52; ++ii) {
    int random_index = rand() % 52;
    int tmp = cards[ii];
    cards[ii] = cards[random_index];
    cards[random_index] = tmp;
  }
}

int main() {
  // Initialize cards.
  int cards[52];
  for (int ii = 0; ii < 52; ++ii) {
    cards[ii] = ii;
  }

  // Print initial list.
  std::cout << "[";
  for (int ii = 0; ii < 52; ++ii) {
    std::cout << cards[ii] << ", ";
  }
  std::cout << "]" << std::endl;

  // Shuffle the list.
  shuffle(cards);

  // Print the shuffled list.
  std::cout << "[";
  for (int ii = 0; ii < 52; ++ii) {
    std::cout << cards[ii] << ", ";
  }
  std::cout << "]" << std::endl;

  return 0;
}
// <--

// ----- Problem 10 ------------------------------------------------------------
// Q. How many times will this loop execute? Explain your answer.
// A. Infinite.  An unsigned char will overflow after 255 while (2 * half_limit) will be 'promoted'
// to an int of value 300 - hence 255 will always be less than 300.
unsigned char half_limit = 150;
for (unsigned char i = 0; i < 2 * half_limit; ++i) {
  // do something;
}

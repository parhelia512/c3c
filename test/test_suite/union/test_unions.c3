module test;

union Qu
{
    Qu *x;
}

union Xe
{
  char c;
  int a, z;
  long b;
  void *b1;
  struct qu
  {
    int a;
    long z;
  }
}

fn Xe foo(Xe a)
{
  a.c = 123;
  a.a = 39249;
  a.b = 12301230123123L;
  a.z = 1;
  return a;
}
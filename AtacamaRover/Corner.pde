class Corner {
  int ident;
  int x;
  int y;


  Corner(int ident_) {
    ident = ident_;
    x = 0;
    y = 0;
  }
  void setPosition(int x_, int y_) {
    x = x_;
    y = y_;
  }
}

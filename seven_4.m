%7.4

fhandle = @(arglist)expr;

%'@' is used for argurments and calling vars

%make anonymous functions

f_x = @(x) 10 * cos(x);
g_x = @(x) 5 * sin(x);
h = @(a,b)sqrt(a.^2 + b.^2);

x = -10:0.2:10;

plot3(x,h(f(x),g(x)));

%im having a prblems graphing this




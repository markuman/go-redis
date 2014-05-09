pkg load instrument-control
addpath inst/

r=redis() % default connection settings

meinematrix=rand(2,2,2)

set(r, meinematrix);

hu=get(r, "meinematrix");

str="gegeben sei dass das hier serialisierter outout ist";

save(r, str);

ja=load(r, "str");

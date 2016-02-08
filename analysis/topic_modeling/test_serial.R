### Test batch script
rm(list=ls())
N=100
n=1000
m1 = m2 = vector(length=n)
for(i in 1:n){
  x = rnorm(N)
  m1[i] = mean(x)
  m2[i] = median(x)
}
save.image(file="image.RData")

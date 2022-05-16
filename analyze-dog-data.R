#!/usr/local/bin/Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)
options(width=80)
options(warn=2)
options(scipen=10)
options(datatable.prettyprint.char=50)
options(datatable.print.class=TRUE)
options(datatable.print.keys=TRUE)
options(datatable.na.strings="")


library(data.table)
library(magrittr)

# ------------------------------ #


dogs <- fread("./data/dogs.csv")

# remove/rename unecessary columns
dogs <- dogs[, .(breed=BreedName, ZipCode, LicenseIssuedDate)]

# the crosswalk between zip codes and boros
xwalk <- fread("./data/zip-boro-xwalk.csv")
xwalk <- xwalk[!duplicated(xwalk)]
setnames(xwalk, "zip", "ZipCode")

setkey(dogs, "ZipCode")
setkey(xwalk, "ZipCode")

# enrich the dog data with non-NA boroughs by merging
# with the crosswalk
dogs %<>% merge(xwalk, all.x=TRUE, by="ZipCode")

# s/Staten$/Staten Island/g
dogs[boro=="Staten", boro:="Staten Island"]

# parse the MM/DD/YYYY date into a POSIX date
dogs[, issued_date:=as.Date(LicenseIssuedDate, format="%m/%d/%Y")]
dogs[, LicenseIssuedDate:=NULL]

# Let's get the number of licenses issues for each year!
# 2014 and 2021 are incomplete, so we'll exclude those
dogs[, .(licenses_issued=.N), year(issued_date)][
  order(year)][
  year <= 2020 & year >= 2015] %>%
    fwrite("./target/dog-licenses-by-year.csv")





# Ok, we want to know each "Borough's Dog Breed"
# Note that it isn't 'the most popular breed in each Borough...

dogs[breed!="Unknown" & !is.na(boro)][
  , .N, .(boro, breed)][
  order(-N)][
  !duplicated(boro)]

# The most popular breed in all boroughs is Yorkshire Terrier (except
# Staten Island [Shih Tzu])

# Instead of the most popular breed, for each Borough, we'll choose the
# breed that's most unique to each Borough
# By this I mean: what's the Breed, in each Borough, that's the most
# popular compared to all other Boroughs.

# For example, Dalmatians aren't a incredibly popular breed, but,
# assuming it were the case that 90% of NYC's Dalmatians lived in
# the Bronx, Dalmatians would be ~"Bronx's signature breed"

# Statistically speaking, each Borough's "breed" would be the breed
# with the highest (positive) residuals in a Chi-Square test of independence
# of proportions between that Borough and all other Borough's



# let's remove all NA boros and 'Unknown' breeds
dogs <- dogs[breed!="Unknown" & !is.na(boro)]

# Let's only use breeds that have >=5,000 occurences in NYC
dogs[, .N, breed][N>=5000][, breed] -> BREEDS_TO_KEEP
dogs <- dogs[breed %chin% BREEDS_TO_KEEP]
dogs[, .N, .(boro, breed)][order(-N)][!duplicated(boro)]



make_nice_contingency <- function(bad_contigency){
  cols <- bad_contigency %>% dimnames %>% {.[[2]]}
  ret <- data.table(breed=row.names(bad_contigency),
                    one=bad_contigency[,1],
                    two=bad_contigency[,2])
  setnames(ret, c("breed", cols[1], cols[2]))
  setorder(ret, -target)
  return(ret[])
}

get_top_dog <- function(DT, targetboro){
  DT[, tmp:=ifelse(boro==targetboro, "target", "nottarget")]
  table(DT$breed, DT$tmp) %>%
    prop.table(margin=2) %>%
    chisq.test %>%
    {.$residuals} -> tmp
  tmp %<>% make_nice_contingency
  return(tmp[1, breed])
}

# let's turn off warnings as errors (chisq is inexact test)
options(warn=1)

# get_top_dog(dogs, "Bronx")
# get_top_dog(dogs, "Staten Island")
# get_top_dog(dogs, "Manhattan")
# get_top_dog(dogs, "Brooklyn")
# get_top_dog(dogs, "Queens")

# run it for all boroughs and output the combined results
list("Bronx", "Manhattan", "Staten Island", "Queens", "Brooklyn") %>%
  lapply(function(x){ data.table(boro=x, signature_breed=get_top_dog(dogs, x)) }) %>%
  rbindlist %>%
  fwrite("./target/boros-signature-breeds.csv")



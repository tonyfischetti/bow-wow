# bow-wow

<p align="center">
  <img src="https://personal.thepolygram.com/haring-dog.svg"
       alt="keith haring dog barking"
       width="200"/>
</p>
<p align="center">A quick demonstration of an ETL pipeline</p>

***

- [quickstart](#quickstart)
- [tell me more](#tell-me-more)
- [tech stack choice](#tech-stack-choice)
- [limitations](#limitations)

***

## quickstart

To run this, you need to have Node.js; R, and the R package `packrat`.

Assuming you already have Node.js and R installed, installing `packrat`
is as easy as opening R and running

```
install.packages("packrat")
```

> Aside: I this were more than a simple demo, I'd probably use Docker, but
> I was on a time-crunch.


After that: clone this repo, and install npm packages needed to build
and the R packages in `packrat/packrat.lock`...

```
$ git clone https://github.com/tonyfischetti/bow-wow
$ npm install

$ # you may not want to globally install gulp-cli, but I find it useful
$ npm install --global gulp-cli

$ R
> # (the R console should note the auto-installation of `magrittr` and `data.table`)
> quit()
```

Everything is all set up now!

The default pseudo-target in the Gulpfile contains all the steps necessary to
build the whole pipeline. Just run `gulp`!

```
$ gulp
```


## tell me more

For this task, I chose to use the NYC Open Portal dataset about dog
licenses.

I struggled for a little bit to find an interesting operation to perform
on the data until I thought of getting each borough's "signature dog breed".
Each borough's ~ "signature" dog breed _isn't_ (necessarily) the borough's
most popular dog breed (after all, Yorkshire Terrier is the most popular
breed in _all_ borough's, save for Staten Island). Instead, the spot goes
to the breed that is the most popular compared to base-popularity of dog
breeds in all other borough's.

For example, Dalmatians aren't a incredibly popular breed, but--assuming
it were the case that 90% of NYC's Dalmatians lived in the Bronx--Dalmatians
would be ~ "Bronx's signature breed".

Statistically speaking, each borough's "breed" would be the breed
with the highest residuals in a Chi-Square test of independence
of proportions between that borough and all others.

Anyway, I noticed that the ZipCodes in the Open data wesen't reliable, so
I added another (unauthorized) data source from nycbynatives.com that
maps zipcodes to boroughs.

> I'm not 100% sure it's trustworthy, but I don't think the veracity of
> the results are the primary concern here.



## tech stack choice

If I were in a bigger rush--or doing this just for me--I'd probably have a
two-line bash script that `curl`s or `wget`s the two data files, a
short python script to parse the DOM / extract the zipcode <-> boro
crosswalk table, and an R script to read both and spit out the final
data products.

Given that this is a demo, though, I decided to use a tech stack / workflow
that's a little closer to that of the NYPL Digital department, and with a
particular emphasis on ease-of-reproducibility.

As mentioned before, if I had more time, I'd probably use Docker to take
care off all that stuff at the OS-level, but I decided to go another way.






### limitations


trust the data

6 high security vulns

unknown

American Pit Bull Terrier/Pit Bull
American Pit Bull Mix / Pit Bull Mix
American Pit Bull Mix / Pit Bull Mix
American Staffordshire Terrier
Staffordshire Bull Terrier
American Bully

Bearded Collie
Collie, Bearded


writing gulpfile as if it were a Makefile


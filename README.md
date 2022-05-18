# bow-wow

<p align="center">
  <img src="https://personal.thepolygram.com/haring-dog.svg"
       alt="keith haring dog barking"
       width="200"/>
</p>
<p align="center">A quick demonstration of an ETL pipeline</p>

***

- [quickstart](#quickstart)
- [just the results, please](#just-the-results-please)
- [tell me more](#tell-me-more)
- [tech stack choice](#tech-stack-choice)
- [limitations](#limitations)
- [list of gulp tasks](#list-of-gulp-tasks)

***

## quickstart

There are two ways to run this ETL pipeline: either completely locally
or through a Docker container.

To see the instructions for the former, switch to the main branch and
re-read this section.

To run this through Docker, you should have Docker installed and be
on a platform that can run Linux containers. I believe that MacOS and
recent Windows versions can do this.

Make sure you're in the project directory and run...

```
./run-thru-docker.sh
```

(If you get a permissions error on a Unix-like OS, you may need to add your
user to the "docker" group (`usermod -a $(whoami) -G docker` and re-login,
or prefix all docker commands in the script with `sudo`.)

This will create the `data` and `target` folders, locally; direct Docker
to share those directories with the container, and build/run the
containerized app.

If it is successful, both the local `data` and `target` folders should be
populated with the raw data and data products, respectively.

Though the rest of the operations are quite fast, it might take 2 minutes
to download the dog license data, and it will take a while to build the
container. All subsequent runs should be lickety-split&mdash;especially
because the pipeline will not re-download the data substrate if it
already exists in `data` and the hash hasn't changed.



## just the results please

Although this is meant to be completely reproducible, the `./target/`
directory was deliberately left-out of the `.gitignore` so that you can
view the results without having to build them from scratch.

- `./target/boros-signature-breeds.csv` contains the 'most uniquely popular'
  dog breed for each Borough of NYC
- `./target/dog-licenses-by-year.csv` is a simple aggregation/count of the
  number of total licenses issues each year



## tell me more

For this task, I chose to use the NYC Open Portal dataset about dog
licenses.

I struggled for a little bit to find an interesting operation to perform
on the data until I thought of getting each borough's "signature dog breed"
or, rather, each borough's 'most uniquely popular dog breed'.
Each borough's "most uniquely popular" dog breed _isn't_ (necessarily) the
borough's most popular dog breed (after all, Yorkshire Terrier is the most
popular breed in _all_ boroughs, save for Staten Island). Instead, the spot
goes to the breed that is the most popular compared to base-popularity of dog
breeds in all other borough's.

For example, Dalmatians aren't an incredibly popular breed,
but&mdash;assuming it were the case that 90% of NYC's Dalmatians lived in
the Bronx&mdash;Dalmatians would be "Bronx's signature breed".

Statistically speaking, each borough's "breed" would be the breed
with the highest (positive) residuals in a Chi-Square test of independence
of proportions between that borough and all others.

Anyway, I noticed that the ZipCodes in the Open data weren't reliable, so
I added another (unauthorized) data source from nycbynatives.com that
maps zipcodes to boroughs.

> I'm not 100% sure it's trustworthy, but I don't think the veracity of
> the results are the primary concern here.



## tech stack choice

If I were in a bigger rush&mdash;or doing this just for me&mdash;I'd
probably have a two-line bash script that `curl`s or `wget`s the two data
files, a short python script to parse the DOM / extract the zipcode
<-> boro crosswalk table, and an R script to read both and spit out the
final data products.

Given that this is a demo, though, I decided to use a tech stack / workflow
that's a little closer to that of the NYPL Digital department, and with a
particular emphasis on ease-of-reproducibility.

The core technologies in this stack are Docker (containerization solution),
Gulp (the build tool), and R (the programming language that reads/processes
the data and outputs the results).

The Gulpfile contains JS recipes to

- clean temporary/derived files (not run by default)
- set up the expanded directory structure
- download the data sources (including parsing the zipcode<->boro crosswalk DOM)
- verify that the hashes of the downloaded data match what is expected
- run the analysis (in an R script) and place the two data products in
  the directory called `./target`.

The recipes make use of the npm modules fs,
[cheerio](https://cheerio.js.org/) for DOM parsing,
[axios](https://axios-http.com) as an HTTP client,
[ora-promise](https://github.com/sindresorhus/ora) for TTY animations,
[md5](https://www.npmjs.com/package/md5) for checking the integrity of
the remote data sources, and [shelljs](https://github.com/shelljs/shelljs)
for the shell commands necessary to run the R script and remove temporary
files/directories.

As I understand it, these are popular node libraries.



## limitations

1. I'm not sure I 100% trust the dog license data since, though my intuition
   tells me that _more_ licenses would have been issued in 2020, these
   data suggest that they _decreased_.

   Even if this data source were trustworthy, there were a lot of
   idiosyncracies in the dataset that need to be further worked-through
   before this is considered a "production-ready" analysis.

   Just as one example, the breed names used do not appear to come from
   a tightly-controlled vocabulary. For example, Pitbulls (this author's
   favorite breed) are referred to by _at least_ 6 different names in the
   data. Though in this particular instance its probably due to attempts
   to subvert breed-specific rules/legislation, the problem extends to
   pretty much all of the most popular breeds.

2. Node.js is very new to me, so I don't know whether the fact that there
   are 6 high security vulnerabilities in the smörgåsbord of NPM dependencies
   is actually a cause for concern or "par for the course" in modern
   server-side dev.

3. Using a Gulpfile as if it were a Makefile might be an unusual choice but
   (a) my testing suggests it works fine, and (b) I wanted to use a tool
   more likely to be popular in Digital.



## list of gulp tasks

```
Tasks for bow-wow/Gulpfile.js
├── clean
├── setup
├─┬ download
│ └─┬ <series>
│   ├── downloadDogData
│   └── downloadZipBoroXwalk
├─┬ check
│ └─┬ <parallel>
│   ├── checkDogData
│   └── checkZipBoroXwalk
├── analyze
└─┬ default
  └─┬ <series>
    ├── setupDirs
    ├─┬ <series>
    │ ├── downloadDogData
    │ └── downloadZipBoroXwalk
    ├─┬ <parallel>
    │ ├── checkDogData
    │ └── checkZipBoroXwalk
    └── analyzeDogData
```


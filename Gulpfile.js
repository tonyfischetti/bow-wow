
'use strict';

const { series, parallel } = require('gulp');

const fs = require("fs");
const cheerio = require("cheerio");
const axios = require("axios");
const spinner = require("ora-promise")
const md5 = require("md5");
const $ = require("shelljs");

/* --------------------------------------------------------------- */

const DOGS = {
  "URL": "https://data.cityofnewyork.us/api/views/nu7n-tubp/rows.csv",
  "MD5": "f214985644c8b2ade4f8cdc30667aa3e",
  "LOC": "./data/dogs.csv",
  "DES": "Dog License Data from NYC Open Portal"
};

const XWALK = {
  "URL": "https://www.nycbynatives.com/nyc_info/new_york_city_zip_codes.php",
  "MD5": "02bd1d96a157e20c0268a0d2351fefcf",
  "LOC": "./data/zip-boro-xwalk.csv",
  "DES": "Zip <-> Borough data from nycbynatives.com"
};

/* --------------------------------------------------------------- */


/* ---------------------------------------------------------------
 *
 * This is the target that creates the `data` and `target`
 * directories.
 *
 */

const setupDirs = (cb) => {
  $.mkdir("-p", "data");
  $.mkdir("-p", "target");
  return cb();
};


/* ---------------------------------------------------------------
 *
 * These are the targets that download the data sources
 * and place them in './data'
 *
 */

const downloadDogData = (cb) => {
  if (fs.existsSync(DOGS.LOC)){
    console.log(`already have ${DOGS.DES}`);
    return cb();
  }
  return spinner(`downloading ${DOGS.DES}`,
    () => axios.get(DOGS.URL)).
    then(resp => fs.promises.writeFile(DOGS.LOC, resp.data)).
    catch(err => console.error(`failure: ${err}`));
};

const downloadZipBoroXwalk = (cb) => {
  if (fs.existsSync(XWALK.LOC)){
    console.log(`already have ${XWALK.DES}`);
    return cb();
  }

  const writer = fs.createWriteStream(XWALK.LOC, { flags: 'w' });

  return spinner(`downloading ${XWALK.DES}`,
    () => axios.get(XWALK.URL)).
    then(resp => cheerio.load(resp.data)).
    catch(err => console.error(`failure: ${err}`)).
    then($ => {
      const zips = $("td:nth-child(1), td:nth-child(4)");
      const boros = $("td:nth-child(2), td:nth-child(5)");
      writer.write(`zip,boro\n`);
      zips.each((i, e) => {
        writer.write(`${$(e).text().trim()},${$(boros[i]).text().trim()}\n`);
      });
    });
};


/* ---------------------------------------------------------------
 *
 * This are the targets that download the data sources
 * and place them in `./data`
 *
 */

const checkDogData = (cb) => {
  return fs.promises.readFile(DOGS.LOC).
    then(buf => {
      if (md5(buf) !== DOGS.MD5){
        throw Error(`Unexpected change in ${DOGS.LOC}`);
      } else {
        console.log("Hash of Dog Data is as expected");
      }
    });
};

// TODO make DRY-er
const checkZipBoroXwalk = (cb) => {
  return fs.promises.readFile(XWALK.LOC).
    then(buf => {
      if (md5(buf) !== XWALK.MD5){
        throw Error(`Unexpected change in ${XWALK.LOC}`);
      } else {
        console.log("Hash of Zip <-> Borough crosswalk is as expected");
      }
    });
};



/* ---------------------------------------------------------------
 *
 * This are the targets that download the data sources
 * and place them in `./data`
 *
 */

const analyzeDogData = (cb) => {
  $.exec("Rscript ./analyze-dog-data.R");
  cb();
};


/* ---------------------------------------------------------------
 *
 * Finally, this is a target that cleans the generated directories
 * and place them in `./data`
 *
 * It's not in the default pipeline because I don't really
 * know what the security ramifications are of force removing
 * a directory.
 *
 */

const mrproper = (cb) => {
  $.rm("-rf", "data")
  $.rm("-rf", "target")
  cb();
};

/* --------------------------------------------------------------- */


/*
 * the "download" target doesn't have to be "series" (as opposed
 * to "parallel") but there's a race condition in TTY output if
 * it's not "series"
 */

exports.clean     = mrproper;
exports.setup     = setupDirs;
exports.download  = series(downloadDogData, downloadZipBoroXwalk);
exports.check     = parallel(checkDogData, checkZipBoroXwalk);
exports.analyze   = analyzeDogData;

exports.default   = series(exports.setup,
                           exports.download,
                           exports.check,
                           exports.analyze);


const fetch = require("node-fetch");
const express = require("express");

const MRP = require("./models/mrp_model");
const Wholesale = require("./models/wholesale_model");
const app = express();

app.get("/", (req, res) => {
  res.json({ msg: "search" });
});


app.get("/api/v1/search", async (req, res) => {
  const mrpPromise = MRP.find({});
  const wholesalePromise = Wholesale.find({});
  const promises = [mrpPromise, wholesalePromise];
  const [mrp, wholesale] = await Promise.all(promises);

  res.json(mrp.concat(wholesale));
});

app.get("/api/v1/search/depends-on", async (req, res) => {
  try {
    
    const mrpPromise = fetch("http://mrp:3000/");
    const wholesalePromise = fetch("http://wholesale:3000/");
    const promises = [mrpPromise, wholesalePromise];
    const [mrpResponse, wholesaleResponse] = await Promise.all(promises);
    const mrpJson = await mrpResponse.json();
    const wholesaleJson = await wholesaleResponse.json();

    res.json({ mrp: mrpJson, wholesale: wholesaleJson });
  } catch (e) {
    res.status(500).json(e);
  }
});

module.exports = app;

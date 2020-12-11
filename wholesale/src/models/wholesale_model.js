const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const WholesaleSchema = new Schema({
  name: String,
  type: { type: String, default: "wholesale" },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Wholesale", WholesaleSchema);

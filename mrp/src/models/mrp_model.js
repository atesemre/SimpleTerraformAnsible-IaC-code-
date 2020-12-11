const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const MRPSchema = new Schema({
  name: String,
  type: { type: String, default: "mrp" },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("MRP", MRPSchema);

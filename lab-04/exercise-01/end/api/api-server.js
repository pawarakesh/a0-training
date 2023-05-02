require('dotenv').config();
const cors = require('cors');
const express = require('express');
const http = require('http');
const { auth, requiredScopes } = require('express-oauth2-bearer');

const appUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT}`;

const app = express();

const expenses = [
  {
    date: new Date(),
    description: 'Pizza for a Coding Dojo session.',
    value: 102,
  },
  {
    date: new Date(),
    description: 'Coffee for a Coding Dojo session.',
    value: 42,
  }
];

app.use(cors());

app.get('/total', (req, res) => {
  const total = expenses.reduce((accum, expense) => (accum + expense.value), 0);
  res.send({total, count: expenses.length});
});

app.use(auth());

app.get('/', requiredScopes('read:reports'), (req, res) => {
  console.log(new Date(req.auth.claims.iat * 1000));
  res.send(expenses);
});

http.createServer(app).listen(process.env.PORT, () => {
  console.log(`listening on ${appUrl}`);
});

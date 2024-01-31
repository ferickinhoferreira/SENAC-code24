import express from 'express';

const app = express();

const clientes = [
    { id: 1, nome: "joão batista"},
    { id: 2, nome: "Erick"}
]

//rota principa
app.get("/", (req, res) => [
    res.status(200).send("Welcome to our app")
]) 

app.get("/clientes", (req, res) => {
    res.status(200).json(clientes);
}) 

app.post("/clientes", (req, res) => {
    clientes.push(req, res)
    res.status(201).send("Clientes principal api-clientes")
})

//consultar todos os clientes
app.get("", (res, res) => {
})

app.get ("/clientes", (req, res))
export default app;
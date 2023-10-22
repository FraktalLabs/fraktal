package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"strconv"
)

func main() { os.Exit(mainImpl()) }

func mainImpl() int {
  // TODO: Importing style.css like './style.css' doesn't work
  filestore := flag.String("filestore", "", "Path to filestore")
  port := flag.Int("port", 8081, "Port to listen on")
  flag.Parse()

  if *filestore == "" {
    log.Println("Must specify --filestore")
    return 1
  }

  http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
    path := *filestore + r.URL.Path[1:]
    http.ServeFile(w, r, path)
  })

  log.Println("Listening on :" + strconv.Itoa(*port))
  log.Fatal(http.ListenAndServe(":" + strconv.Itoa(*port), nil))

  return 0
}

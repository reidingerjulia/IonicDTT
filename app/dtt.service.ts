import { Injectable } from '@angular/core';
import { Elm } from '../assets/js/main.js';
import { flag } from './Models/flag.js';
import { isString } from 'util';
import { Todo } from './Models/todo.js';
import { Data } from './Models/data.js';
import { Observable, BehaviorSubject, from, merge } from 'rxjs';
import { share } from 'rxjs/operators';

//declare var app: any;
@Injectable({
  providedIn: 'root'
})
export class DTTService {
  todo: object[];
  flag: flag;
  data: Data;
  app: any;
  userHasLoggedIn: boolean = false;
  constructor() {
    //Love You
  }
  init(username: String) {
    console.log(`login user: ${username}....`);
    try {
      this.app = Elm.Main.init({
        flags:
        {
          user: username,
          currentTime: Date.now(),
          initialSeed: Math.random()
        }
      });
      this.userHasLoggedIn = true;
      this.subscribeToDataStream();

      console.log("login success");
    } catch (error) {
      console.log(`login failed: ${error.message}`);
    }

  }
  send(jsonObject: object) {
    try {
      console.log(`Try sending...`);
      this.app.ports.toElm.send(jsonObject);
      //this.syncTodo();
    } catch (error) {
      console.log(`Sending failed:${error.message}`);
    }
  }
  subscribeToDataStream(): Observable<object> {
    console.log(`subscribe to datastream...`);

    return this.app.ports.fromElm.subscribe(data => {
      this.data = data;
      console.log(data);
    });

    //this.syncTodo();
  }
  
  insertTodo(content: String){
    this.send({
      page: "todo"
      , action: "insert"
      , id: null
      , content: null
    });
  }
  insertSecret(content: String){
    this.send({
      page: "secrets"
      , action: "insert"
      , id: null
      , content: content
    });
  }
  syncTodo() {
    this.send({
      page: "todo"
      , action: "sync"
      , id: null
      , content: null
    });
  }
  syncSecret() {
    this.send({
      page: "secrets"
      , action: "sync"
      , id: null
      , content: null
    });
  }
  deleteTodo(id: String){
    this.send({
      page: "todo"
      , action: "delete"
      , id: id
      , content: null
    });
  }
  deleteSecret(content: String){
    this.send({
      page: "secrets"
      , action: "delete"
      , id: null
      , content: content
    });
  }
  updateTodo(id: String, content: String){
    this.send({
      page: "todo"
      , action: "update"
      , id: id
      , content: content
    });
  }
  public getData(): Observable<Data>{ //Richtiger Code!!!
    console.log('Loading data');
    const observable = this.app.ports.fromElm;
    
    observable.subscribe(data => this.data = data);
    return observable;
  }
  /* public getEmployees(): Observable<Employee[]> {
    console.log('Loading employees');
    const observable = this.http
      .get<Employee[]>(`${this.baseurl}/LoadEmployeeData`)
      .pipe(share());
    observable.subscribe(x => this.nrEmployees = x.length);
    return observable;
  } */
  
}

import { Component } from '@angular/core';
import { DTTService } from '../dtt.service';
import { AlertController, ToastController } from '@ionic/angular';
import { Todo } from '../Models/todo';
import { LoadingController } from '@ionic/angular';
import {Error } from '../Models/error';


@Component({
  selector: 'app-tab1',
  templateUrl: 'tab1.page.html',
  styleUrls: ['tab1.page.scss']
})
export class Tab1Page {
  todos: Todo[];
  error: Error;
  constructor(public toastController: ToastController,public loadingController: LoadingController,public service: DTTService, public alertController: AlertController) { }

  ngOnInit(){ //Richtiger Code!!
    this.service.getData().subscribe(x => {
      if(x.error != null){
        console.log(x.error.errorType);
        this.presentToast(x.error.errorType);
      }else{
        this.todos = x.todo;
      }
      
    });
  }
  addNewTodo() {
    console.log("addNewTodo...");
    this.presentAddPrompt();
  }
  delete(item) {
    console.log("delete...");
    this.service.deleteTodo(item.id);
  }
  update(item) {
    console.log("update...");
    this.presentEditPrompt(item);
  }
  async presentToast(error: String) {
    const toast = await this.toastController.create({
      message: error.toString(),
      duration: 2000
    });
    toast.present();
  }
  async presentAddPrompt() {
    const alert = await this.alertController.create({
      header: 'Add New Todo!',
      inputs: [
        {
          name: 'content',
          type: 'text',
          placeholder: 'Content'
        }
      ],
      buttons: [
        {
          text: 'Cancel',
          role: 'cancel',
          cssClass: 'secondary',
          handler: () => {
            console.log('Confirm Cancel');
          }
        }, {
          text: 'Ok',
          handler: (data) => {
            console.log('Confirm Ok');
            this.service.send({
              page: "todo",
              action: "insert",
              id:null,
              content: data.content
            });
          }
        }
      ]
    });

    await alert.present();
  }
  async presentEditPrompt(item: Todo) {
    const alert = await this.alertController.create({
      header: 'Edit Todo!',
      inputs: [
        {
          name: 'content',
          type: 'text',
          placeholder: ''+item.message
        }
      ],
      buttons: [
        {
          text: 'Cancel',
          role: 'cancel',
          cssClass: 'secondary',
          handler: () => {
            console.log('Confirm Cancel');
          }
        }, {
          text: 'Ok',
          handler: (data) => {
            console.log('Confirm Ok');
            this.service.send({
              page: "todo",
              action: "update",
              id:item.id,
              content: data.content
            });
          }
        }
      ]
    });

    await alert.present();
  }
}

import { Component } from '@angular/core';
import { AngularFireDatabase } from '@angular/fire/database';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  items: Observable<any[]>;
  title = 'Beyond Rest';
  constructor(db: AngularFireDatabase) {
    this.items = db.list('data').valueChanges();
  }
}

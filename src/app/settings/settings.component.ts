import { Component, OnInit } from '@angular/core';
import { AngularFireDatabase } from '@angular/fire/database';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.css']
})
export class SettingsComponent implements OnInit {
  settings: Observable<any>;

  constructor(private db: AngularFireDatabase) { }

  ngOnInit() {
    this.settings = this.db.object('settings').valueChanges();
  }
}

import { Component } from '@angular/core';
import { AngularFireDatabase, AngularFireObject } from '@angular/fire/database';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  items: Observable<any[]>;
  settingsRef: AngularFireObject<any>;
  settings: any;

  constructor(db: AngularFireDatabase) {
    this.settingsRef = db.object('settings');
    this.settingsRef.snapshotChanges().subscribe(action => {
      this.settings = action.payload.val();

      this.items = db.list('data').valueChanges().pipe(map(x => {
        x.forEach((e) => {
          const c = e as any;
          c.name = this.settings.transmitter[c.transmitter_id].name;
          c.sensors.forEach(s => s.name = this.settings.transmitter[c.transmitter_id].sensors[s.sensor - 1]);
        });
        return x;
      }));
    });
  }
}

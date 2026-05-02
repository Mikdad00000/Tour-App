import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { depositTemplate } from './notificationTemplates';

export const onDepositCreated = onDocumentCreated(
  'trips/{tripId}/deposits/{depositId}',
  async (event) => {
    const d = event.data?.data();
    if (!d) return;
    const { tripId } = event.params as { tripId: string };
    const tripSnap = await admin.firestore().collection('trips').doc(tripId).get();
    const adminId = tripSnap.data()?.adminId as string | undefined;
    if (!adminId) return;
    const adminSnap = await admin.firestore().collection('users').doc(adminId).get();
    const tok = adminSnap.data()?.fcmToken as string | undefined;
    if (!tok) return;
    const tmpl = depositTemplate(d.amount as number, d.userId as string);
    await admin.messaging().send({
      token: tok,
      notification: { title: tmpl.title, body: tmpl.body },
      data: { tripId, depositId: event.params.depositId as string, type: 'deposit' },
    });
  },
);

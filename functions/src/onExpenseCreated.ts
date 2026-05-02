import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import {
  ExpenseDoc,
  expenseTemplate,
  loanRepaidTemplate,
} from './notificationTemplates';

async function fcmTokensFor(userIds: string[]): Promise<Map<string, string>> {
  const result = new Map<string, string>();
  if (userIds.length === 0) return result;
  const snaps = await admin.firestore().getAll(
    ...userIds.map((u) => admin.firestore().collection('users').doc(u)),
  );
  for (const s of snaps) {
    const t = (s.data()?.fcmToken as string | undefined) ?? null;
    if (t) result.set(s.id, t);
  }
  return result;
}

async function logActivity(
  tripId: string,
  type: string,
  payload: Record<string, unknown>,
  recipients: string[],
): Promise<void> {
  await admin.firestore().collection('trips').doc(tripId).collection('activity').add({
    type,
    payload,
    recipients,
    readBy: [],
    createdAt: new Date().toISOString(),
  });
}

export const onExpenseCreated = onDocumentCreated(
  'trips/{tripId}/expenses/{expenseId}',
  async (event) => {
    const e = event.data?.data() as ExpenseDoc | undefined;
    if (!e) return;
    const { tripId, expenseId } = event.params as { tripId: string; expenseId: string };

    let recipients: string[] = [];
    if (e.type === 'shared') {
      const tripSnap = await admin.firestore().collection('trips').doc(tripId).get();
      const memberIds = (tripSnap.data()?.memberIds as string[]) ?? [];
      recipients = memberIds.filter((m) => m !== e.paidBy);
    } else if (e.type === 'partial') {
      const tripSnap = await admin.firestore().collection('trips').doc(tripId).get();
      const memberIds = (tripSnap.data()?.memberIds as string[]) ?? [];
      recipients = memberIds.filter((m) => m !== e.paidBy);
    } else if (e.type === 'peer_loan') {
      recipients = e.participants.filter((p) => p !== e.paidBy);
    } else {
      // individual: no notifications
      return;
    }

    const tokens = await fcmTokensFor(recipients);
    const messages: admin.messaging.Message[] = [];
    for (const uid of recipients) {
      const tok = tokens.get(uid);
      if (!tok) continue;
      const tmpl = expenseTemplate(e, uid);
      messages.push({
        token: tok,
        notification: { title: tmpl.title, body: tmpl.body },
        data: { tripId, expenseId, type: e.type },
      });
    }
    if (messages.length > 0) {
      await admin.messaging().sendEach(messages);
    }
    await logActivity(tripId, e.type, { expenseId, ...e }, recipients);
  },
);

export const onExpenseUpdated = onDocumentUpdated(
  'trips/{tripId}/expenses/{expenseId}',
  async (event) => {
    const before = event.data?.before.data() as ExpenseDoc | undefined;
    const after = event.data?.after.data() as ExpenseDoc | undefined;
    if (!before || !after) return;
    if (after.type !== 'peer_loan') return;
    if (before.loanStatus !== 'repaid' && after.loanStatus === 'repaid') {
      const { tripId, expenseId } = event.params as { tripId: string; expenseId: string };
      const recipients = [after.paidBy, ...after.participants.filter((p) => p !== after.paidBy)];
      const tokens = await fcmTokensFor(recipients);
      const tmpl = loanRepaidTemplate(after);
      const messages: admin.messaging.Message[] = recipients
        .map((uid) => tokens.get(uid))
        .filter((t): t is string => !!t)
        .map((tok) => ({
          token: tok,
          notification: { title: tmpl.title, body: tmpl.body },
          data: { tripId, expenseId, type: 'loan_repaid' },
        }));
      if (messages.length > 0) {
        await admin.messaging().sendEach(messages);
      }
      await logActivity(tripId, 'repayment', { expenseId, ...after }, recipients);
    }
  },
);

import * as admin from 'firebase-admin';

admin.initializeApp();

export { onExpenseCreated, onExpenseUpdated } from './onExpenseCreated';
export { onDepositCreated } from './onDepositCreated';

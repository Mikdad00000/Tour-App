export type ExpenseDoc = {
  type: 'shared' | 'partial' | 'individual' | 'peer_loan';
  paidBy: string;
  fromPool: boolean;
  participants: string[];
  witnesses: string[];
  amount: number;
  perHeadAmount: number;
  category?: string;
  note?: string;
  location?: { lat: number; lng: number; placeName?: string };
  loanStatus?: 'pending' | 'repaid' | null;
};

export type Tmpl = { title: string; body: string };

const fmt = (n: number) => `৳${n.toFixed(0)}`;

export function expenseTemplate(e: ExpenseDoc, recipientUserId: string): Tmpl {
  const place = e.location?.placeName ? ` @ ${e.location.placeName}` : '';
  const what = e.note ?? e.category ?? 'খরচ';

  if (e.type === 'shared') {
    return {
      title: `গ্রুপ খরচ: ${fmt(e.amount)}${place}`,
      body: `${what} — আপনার ভাগ ${fmt(e.perHeadAmount)}`,
    };
  }
  if (e.type === 'partial') {
    if (e.participants.includes(recipientUserId)) {
      return {
        title: `গ্রুপ খরচ (পার্শিয়াল): ${fmt(e.amount)}${place}`,
        body: `${what} — আপনার ভাগ ${fmt(e.perHeadAmount)}`,
      };
    }
    return {
      title: `Info: ওরা ${what} খাচ্ছে${place}`,
      body: `${e.participants.length} জন ভাগ করছে ${fmt(e.amount)} — আপনার ভাগে কিছু পড়বে না`,
    };
  }
  if (e.type === 'peer_loan') {
    return {
      title: `ধার: আপনি ${fmt(e.perHeadAmount)} দিবেন`,
      body: `${what} — Accept বা Dispute করুন`,
    };
  }
  return { title: 'Tour', body: 'নতুন এন্ট্রি' };
}

export function loanRepaidTemplate(e: ExpenseDoc): Tmpl {
  return {
    title: `ধার শোধ: ${fmt(e.amount)}`,
    body: `${e.note ?? 'লোন'} — settled`,
  };
}

export function depositTemplate(amount: number, byUserId: string): Tmpl {
  return {
    title: `নতুন জমা: ${fmt(amount)}`,
    body: `${byUserId.slice(0, 6)} জমা দিল — confirm করো`,
  };
}

export const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const isValidPassword = (password) => {
  const passwordRegex =
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return passwordRegex.test(password);
};


export const isValidMobile = (mobile) => {
  // Use E.164 recommended pattern: optional leading +, country code (no leading 0),
  // followed by subscriber number; total digits between 2 and 15.
  const mobileRegex = /^\+?[1-9]\d{1,14}$/;
  return mobileRegex.test(mobile);
};

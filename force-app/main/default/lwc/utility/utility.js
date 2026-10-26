export function mobileNumberValidation(value) {
    console.log('value in utility----', value);
    
    if ( value.match(/^[6789]\d{9}$/)) {
        console.log('Inside if condition');
        
        return true;
    }
     else {
        return false;
    }
}
//Added by Kshitiz AHL 26/09/2025 for timeout function
export function withTimeout(promise, ms){
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            reject(new Error("Operation timed out"));
        }, ms);
        promise
            .then((value) => {
                clearTimeout(timer);
                resolve(value);
            })
            .catch((err) => {
                clearTimeout(timer);
                reject(err);
            });
    });
}
export function textValidation(value) {
    const hasAlphabet = /[a-zA-Z]/.test(value);
    console.log('hasAlphabet--',hasAlphabet);
    if(hasAlphabet){
        return true;
    } else {
        return false;
    }
}
export function numberValidation(value) {
    const hasNumber = /[0-9]/.test(value);
    const hasAlphabetSpecial = /\D/.test(value); // Allows only letters and spaces
     console.log('hasAlphabetSpecial--',hasAlphabetSpecial);
    if (hasAlphabetSpecial) {
        return true;
    } else {
        return false;
    }
}
export function validateNameOfOrganisation(input){
    const regex = /^[a-zA-Z0-9][a-zA-Z0-9 &()_.-]*$/;
    return regex.test(input);
}

export function checkSpecialCharacter(value){
    
        const regex = /^[a-zA-Z\s]*$/;
        return regex.test(value);
    
}
export function checkalphnumeric(input){
    const regex = /^[a-zA-Z0-9]*$/;
    return regex.test(input);
}
export function charLength(value){
    if(value){
        return value.length;
    }else{
        return 0;
    }
    
}

export function validateIndividualPAN(pan) {
    const individualPanRegex = /^(?!.*[DFOIL])[A-Z]{3}P[0-9]{4}[A-Z]{1}$/;
    return individualPanRegex.test(pan);
}

export function validateNonIndividualPAN(pan, constitution) {
    // LLP- F
    // HUF, Private Limited- H
    // Public Limited- C
    // Proprietorship- P
    // Partnership - F
    console.log('constitution in utility----', constitution);
    if(constitution== 'LLP' || constitution== 'Partnership'){
        if (pan.match(/[A-Z]{3}F[A-Z][0-9]{4}[A-Z]/)) {
            console.log('Inside correct panNumberValidation');
            return true;
        } else {
            return false;
        }
    }else if(constitution== 'HUF' ){
        if (pan.match(/[A-Z]{3}H[A-Z][0-9]{4}[A-Z]/)) {
            console.log('Inside correct panNumberValidation');
            return true;
        } else {
            return false;
        }
    }else if(constitution== 'Public Limited' || constitution== 'Private Limited'){
        if (pan.match(/[A-Z]{3}C[A-Z][0-9]{4}[A-Z]/)) {
            console.log('Inside correct panNumberValidation');
            return true;
        } else {
            return false;
        }
    }else if(constitution== 'Proprietorship'){
        if (pan.match(/[A-Z]{3}P[A-Z][0-9]{4}[A-Z]/)) {
            console.log('Inside correct panNumberValidation');
            return true;
        } else {
            return false;
        }
    }else{
        return false;
    }
    
    const nonIndividualPanRegex = /^][A-Z]{3}[P|C|H|A|B|G|J|L|E|F|T|c|p|h|a][A-Z][0-9]{4}[A-Z]{1}$/;
    return nonIndividualPanRegex.test(pan);
}

export function validateTANNumber(value) {
    if (value.match(/[A-Z]{4}[0-9]{5}[A-Z]/)) {
        console.log('Inside correct panNumberValidation');
        return true;
    } else {
        return false;
    }
    
}

export function isValidMobileNumber(input) {
    const regex = /^[0-9]+$/;  // Allows only digits
    return regex.test(input);
}
export function shareHolderNameValidation(value) {
    const regex = /^[A-Za-z\s]+$/; // Allows only letters and spaces
    return regex.test(value);
}
export function bsrCodeValidation(value) {
    if (value.match(/^[0-9]{7}$/)) {
        console.log('Inside if bsrCodeValidation');
        return true;
    } else {
        return false;
    }
}
export function panNumberValidation(value) {
    if (value.match(/[A-Z]{3}P[A-Z][0-9]{4}[A-Z]/)) {
        console.log('Inside correct panNumberValidation');
        return true;
    } else {
        return false;
    }

    // if (value.match(/[A-Za-z]{3}P[A-Za-z]{1}[0-9]{4}[A-Za-z]{1}/)) {
    //     console.log('Inside correct panNumberValidation');
    //     return true;
    // } else {
    //     return false;
    // }
}

export function gstNumberValidation(value) {
    const gstPattern = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}[Z]{1}[A-Z0-9]{1}$/;
    if (value.match(gstPattern)) {
        console.log('Inside correct gstNumberValidation');
        return true;
    } else {
        return false;
    }
}


export function pincodeValidation(value) {
    if (value.match(/^[1-9][0-9]{5}$/)) {
        console.log('Inside if pincodeValidation');
        return true;
    } else {
        return false;
    }
}

// export function ageValidation(value) {
//     const parts = value.split("-");
//     const dobYear = parts[0];
//     const today = new Date().toISOString().split("T")[0].split('-')[0]; // YYYY-MM-DD format
//     const currentYear = today.split('-')[0];
    
//     return currentYear - dobYear > 0; // Adjust this logic as per your requirement
// }

export function isNotFutureDate(selectedDate) {
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Reset time to compare only date
    const inputDate = new Date(selectedDate);

    return inputDate <= today; // Returns true if not a future date
}

export function isUnder18(selectedDate) {
    const today = new Date();
    const birthDate = new Date(selectedDate);
    
    const age = today.getFullYear() - birthDate.getFullYear();

    if (age < 18){
        return true;
    } 
    
    return false;
}


export function emailValidation(value) {
    if (value.match(/^[A-Za-z0-9](\.?[A-Za-z0-9_%+-])*@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$/)) {
        return true;
    } else {
        return false;
    }
}


export function udyamValidation(value) {
    if (value.match(/^UDYAM-[A-z]{2}-\d{2}-\d{7}$/)) {
        return true;
    } else {
        return false;
    }
}

export function validateDLNumber(value) {
    if (value.match(/[A-Z]{2}[0-9]{13}/)) {
        console.log('Inside correct dlNumberValidation');
        return true;
    } else {
        return false;
    }
}

export function validatePassportNumber(value) {
    if (!value) return false;

    const cleanedValue = value.trim().toUpperCase();

    if (
        /^[A-PR-WY][0-9]{7}$/.test(cleanedValue) ||   // Old format
        /^[A-PR-WY]{2}[0-9]{6}$/.test(cleanedValue)  // New format
    ) {
        console.log('Inside correct passportNumberValidation');
        return true;
    } else {
        return false;
    }
}

export function validateVoterIdNumber(value) {
    if (value.match(/[A-Z]{3}[0-9]{7}/)) {
        console.log('Inside correct voterNumberValidation');
        return true;
    } else {
        return false;
    }
}

export function validateAddress(str) {
    const regex = /^[A-Za-z0-9][A-Za-z0-9#&()_\-., \/]*$/;
    return regex.test(str);
}

export function validateOrganizationName(name) {
    if (name.length > 100) {
        return "Name of Organisation must not exceed 100 characters.";
    }

    if (/^[^a-zA-Z0-9]/.test(name)) {
        return "Name of Organisation must not start with a special character.";
    }

    if (/\s{2,}/.test(name)) {
        return "Only a single space is allowed between words.";
    }

    const allowedCharacters = /^[a-zA-Z0-9&._ ()-]+$/;
    if (!allowedCharacters.test(name)) {
        return "Name of Organisation contains invalid characters.";
    }

    return "Success";
}
export function validateOnlyAlphabetsAndSpaces(input) {
    const regex = /^[a-zA-Z\s]+$/;
    return regex.test(input);
}
export function validateDecimalNumber(input) {
    const regex = /^[0-9]+(\.[0-9]{1,2})?$/;
    return regex.test(input);
}
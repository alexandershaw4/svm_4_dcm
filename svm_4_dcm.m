classdef svm_4_dcm
   properties
      A           % the data {cell array of dcm files in sub by group}
      Pc          % percent of the data to use for training (e.g. 80)
      P           % the posterior parameter to extract [from DCM.Ep.(x)]
      DoPermute   % binary y/n
      nperm       % number of permutations
      f           % inbuil svm machine: @fitNaiveBayes or @svmtrain
      Scl         % Scale vectors [0/1]
   end
   methods
       
      function r = svm(obj)
         % svm train & classify function, optionally using machine: (f).
         r = svm_dcm_f(obj.A, obj.Pc, obj.P, obj.DoPermute,obj.f);
      end
      function r = svmp(obj)
         % permutation wrapper on the above
         r = svm_dcm_p(obj.A, obj.Pc, obj.P, obj.nperm, obj.Scl);
         
      end
      
   end
end
